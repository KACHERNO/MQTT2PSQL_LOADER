package mqtt2pg

import (
	"fmt"
	"os"
	"os/signal"
	"sync"
	"syscall"

	"log"

	"database/sql"

	mqtt "github.com/eclipse/paho.mqtt.golang"
	_ "github.com/lib/pq"
)

var messagePubHandler mqtt.MessageHandler = func(client mqtt.Client, msg mqtt.Message) {
	log.Printf("Received message from: %s size: %d", msg.Topic(), len(msg.Payload()))

	insertStmt := `insert into "events" ( "payload" , "topic" ) values ( $1, $2 )`

	_, err := Db.Exec(insertStmt, msg.Payload(), msg.Topic())
	if err != nil {
		log.Printf("Database Insert Error: %s", err.Error())
		// os.Exit(1)
	}
}

var connectHandler mqtt.OnConnectHandler = func(client mqtt.Client) {
	log.Printf("Connected to broker %s", Cfg.MqttBroker.MqttUri)
}

var connectLostHandler mqtt.ConnectionLostHandler = func(client mqtt.Client, err error) {
	log.Printf("Connect lost: %v", err)
}

var Db *sql.DB
var Cfg *Config

func Starter(config Config) {

	Cfg = &config
	// log.Fatalln(Cfg)

	// var host = "localhost"
	// var port = 5432
	// var user = "postgres"
	// var password = "1qaz!QAZ1qaz"
	// var dbname = "postgres"
	var host = Cfg.PsqlHost
	var port = Cfg.PsqlPort
	var user = Cfg.PsqlUser
	var password = Cfg.PsqlPasword
	var dbname = Cfg.PsqlDatabase

	// psqlconn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable", host, port, user, password, dbname)
	psqlconn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable", host, port, user, password, dbname)

	db, err := sql.Open("postgres", psqlconn)
	if err != nil {
		log.Printf("Database Connect Error: %s", err.Error())
		os.Exit(1)
	}
	defer db.Close()
	err = db.Ping()
	if err != nil {
		log.Printf("Database Check Error: %s", err.Error())
		os.Exit(1)
	}
	log.Printf("Connected to database: %s at %s:%s", dbname, host, port)
	Db = db

	// chanStop := make(chan bool) // stop <- true
	chanStop := make(chan os.Signal, 1)
	signal.Notify(chanStop, syscall.SIGHUP, syscall.SIGINT, syscall.SIGTERM, syscall.SIGQUIT)
	//
	//
	//
	var WaitGo sync.WaitGroup
	WaitGo.Add(1)
	go Subcriber(chanStop, &WaitGo)
	// Ждем завершения всех горутин
	WaitGo.Wait()
	log.Println("Service Stopped...")

}

func Subcriber(stop <-chan os.Signal, wg *sync.WaitGroup) {
	// var broker = "mqtt.auton.ru"
	// var port = 48709
	// var topic = "Auton_json/#"
	brokerUri := Cfg.MqttBroker.MqttUri
	topic := Cfg.MqttBroker.MqttTopic
	brokerUser := Cfg.MqttBroker.MqttUser
	brokerPassword := Cfg.MqttBroker.MqttPassword
	brokerClientId := Cfg.MqttBroker.MqttClienId
	opts := mqtt.NewClientOptions()
	opts.AddBroker(brokerUri)
	opts.SetClientID(brokerClientId)
	opts.SetUsername(brokerUser)
	opts.SetPassword(brokerPassword)
	opts.SetDefaultPublishHandler(messagePubHandler)
	opts.OnConnect = connectHandler
	opts.OnConnectionLost = connectLostHandler
	client := mqtt.NewClient(opts)
	defer client.Disconnect(250)

	if token := client.Connect(); token.Wait() && token.Error() != nil {
		panic(token.Error())
	}

	token := client.Subscribe(topic, 1, nil)
	token.Wait()
	log.Printf("Subscribed to topic: %s", topic)
	// 	time.Sleep(time.Second * 2500)
	//  waiting chanel stop
	for stopSignal := range stop {
		fmt.Println("")
		log.Printf("Stopped Worker by %s...", stopSignal.String())
		wg.Done()
		return
	}

}
