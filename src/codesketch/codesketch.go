package main

import "flag"
import "fmt"
import "os"
import "os/user"

const BASE_URL="https://github.com/quirinobrizi/codesketch/archive/"
const VERSION="0.0.8"

type Config struct {
	command string
	arguments map[string]string
}

type Command interface {
	Name() string
	Execute(map[string]string) error
}

func getValue(cf *flag.Flag) string {
	var v = cf.Value.String()
	if len(v) == 0 {
		v = cf.DefValue
	}
	return v
}

func getInstallDirectory() string {
	usr,err := user.Current()
	if  err != nil {
		panic(err)
	}
	var dir = usr.HomeDir
    return fmt.Sprintf("%s/.codesketch/", dir)
}

func parseCommandFlags(args []string) *Config {
	var configureCommand = flag.NewFlagSet("configure", flag.ExitOnError)
	configureCommand.String("server-name", "codesketch.internal", "Codesketch DNS, default to codesketch.internal")
	configureCommand.String("certificate", "codesketch.crt", "The certificate to use for configuring the HTTPS connection")
	configureCommand.String("certificate-key", "codesketch.key", "The key to use for configuring the HTTPS connection")
	configureCommand.String("swarm", "", "Configure for running on swarm on the defined provider, available providers: virtualbox")

	var startCommand = flag.NewFlagSet("start", flag.ExitOnError)
	startCommand.String("swarm", "", "Configure for running on swarm on the defined provider, available providers: virtualbox")

	var stopCommand = flag.NewFlagSet("start", flag.ExitOnError)
	stopCommand.String("swarm", "", "Configure for running on swarm on the defined provider, available providers: virtualbox")

	var cleanCommand = flag.NewFlagSet("start", flag.ExitOnError)
	cleanCommand.String("swarm", "", "Configure for running on swarm on the defined provider, available providers: virtualbox")

	var conf *Config
	switch args[0] {
		case "configure":
			configureCommand.Parse(args[1:])
			conf = &Config{command: "configure", arguments: map[string]string{
				"cert": getValue(configureCommand.Lookup("certificate")),
				"key": getValue(configureCommand.Lookup("certificate-key")),
				"serverName": getValue(configureCommand.Lookup("server-name")),
				"swarm": getValue(configureCommand.Lookup("swarm")),
				"baseUrl": BASE_URL,
			}}
		case "start":
			startCommand.Parse(args[1:])
			conf = &Config{command: "start", arguments: map[string]string{
				"swarm": getValue(startCommand.Lookup("swarm")),
			}}
		case "stop":
			stopCommand.Parse(args[1:])
			conf = &Config{command: "stop", arguments: map[string]string{
				"swarm": getValue(stopCommand.Lookup("swarm")),
			}}
		case "clean":
			cleanCommand.Parse(args[1:])
			conf = &Config{command: "clean", arguments: map[string]string{
				"swarm": getValue(cleanCommand.Lookup("swarm")),
			}}
		default:
			fmt.Printf("%q is not valid command.\n", args[1])
			os.Exit(2)
	}
	conf.arguments["version"] = VERSION
	conf.arguments["installDirectory"] = getInstallDirectory()
	return conf
}

func initCommands() map[string]Command {
	var cmds = make(map[string]Command)
	cmds["configure"] = &configure{s: shell{}, f: file{}}
	cmds["start"] = &start{s: shell{}}
	return cmds
}

func main() {
	if len(os.Args) == 1 {
		return
	}
	var commands = initCommands()
	var conf = parseCommandFlags(os.Args[1:])
	cmd, ok := commands[conf.command]
	if !ok {
		fmt.Printf("Command %q is not defined", conf.command)
		os.Exit(1)
	}
	cmd.Execute(conf.arguments)
}
