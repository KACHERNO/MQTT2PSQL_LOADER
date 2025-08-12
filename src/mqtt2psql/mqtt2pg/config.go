package mqtt2pg

import (
	"log"
	"os"

	"github.com/ilyakaznacheev/cleanenv"
)

type Config struct {
	PsqlServer `yaml:"psql_server"`
	MqttBroker `yaml:"mqtt_broker"`
}

type PsqlServer struct {
	PsqlHost     string `yaml:"psqlHost"  env-default:"localhost"`
	PsqlPort     string `yaml:"psqlPort"  env-default:"5432"`
	PsqlDatabase string `yaml:"psqlDatabase" env-default:""`
	PsqlUser     string `yaml:"psqlUser"  env-default:""`
	PsqlPasword  string `yaml:"psqlPassword"  env-default:""`
}

type MqttBroker struct {
	MqttUri      string `yaml:"mqttUri"  env-default:""`
	MqttTopic    string `yaml:"mqttTopic" env-default:""`
	MqttClienId  string `yaml:"mqttClientId" env-default:""`
	MqttUser     string `yaml:"mqttUser" env-default:""`
	MqttPassword string `yaml:"mqttPassword" env-default:""`
}

func ConfigLoad() *Config {

	configPath := os.Getenv("CONFIG_PATH")
	if configPath == "" {
		configPath = "../config/config.yaml"
		log.Println("CONFIG_PATH environment variable is not set... Read default from " + configPath)
	}

	if _, err := os.Stat(configPath); err != nil {
		log.Println("Error opening config file: " + err.Error())
		os.Exit(1)
	}

	var cfg Config

	err := cleanenv.ReadConfig(configPath, &cfg)
	if err != nil {
		log.Println("error reading config file: " + err.Error())
		os.Exit(1)
	}

	// log.Printf("=== %s", cfg.PsqlServer)

	return &cfg
}
