package main

import (
	"log"
	"mqtt2pg"
	"os"
)

// jwt_secret := os.Getenv("JWT_SECRET")
// if jwt_secret == "" {
// 	logrus.Fatal("Environment variable JWT_SECRET is not set. Exit...")
// }

// psql_server:
//   psqlHost: "localhost"
//   psqlPort: 5432
//   psqlUser: "postgres"
//   psqlPasword: "1qaz!QAZ1qaz"
// mqtt_broker:
//   mqttUri: "mqtt://mqtt.auton.ru:48709"
//   mqttTopic: "Auton_json/#"
//   mqttUser: "test"
//   mqttPassword: "test"

var Cfg *mqtt2pg.Config

func main() {

	Cfg = mqtt2pg.ConfigLoad()

	// log.Fatalln(Cfg)

	if Cfg.PsqlServer.PsqlHost == "" {
		log.Fatalln("Unknown configuration psqlHost...")
	}
	if Cfg.PsqlServer.PsqlPort == "" {
		log.Fatalln("Unknown configuration psqlPort...")
	}
	if Cfg.PsqlServer.PsqlDatabase == "" {
		log.Fatalln("Unknown configuration psqlDatabase...")
	}
	if Cfg.PsqlServer.PsqlUser == "" {
		log.Fatalln("Unknown configuration psqlUser...")
	}
	if Cfg.PsqlServer.PsqlPasword == "" {
		envPsqlPassword := os.Getenv("PSQL_PASSWORD")
		if envPsqlPassword == "" {
			log.Fatalln("Envinonment variable PSQL_PASSWORD not set...")
		} else {
			Cfg.PsqlServer.PsqlPasword = envPsqlPassword
		}
	}
	if Cfg.MqttBroker.MqttUri == "" {
		log.Fatalln("Unknown configuration mqttUri...")
	}
	if Cfg.MqttBroker.MqttTopic == "" {
		log.Fatalln("Unknown configuration mqttTopic...")
	}
	if Cfg.MqttBroker.MqttClienId == "" {
		log.Fatalln("Unknown configuration mqttClienId...")
	}
	if Cfg.MqttBroker.MqttUser == "" {
		log.Fatalln("Unknown configuration mqttUser...")
	}
	if Cfg.MqttBroker.MqttPassword == "" {
		envMqttPassword := os.Getenv("MQTT_PASSWORD")
		if envMqttPassword == "" {
			log.Fatalln("Envinonment variable MQTT_PASSWORD not set...")
		} else {
			Cfg.MqttBroker.MqttPassword = envMqttPassword
		}
	}
	mqtt2pg.Starter(*Cfg)
}
