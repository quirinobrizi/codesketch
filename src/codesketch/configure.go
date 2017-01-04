package main

import (
	"fmt"
	"io"
	"net/http"
	"os"
	"archive/zip"
	"path/filepath"
  "strings"
	"net"
	"errors"
)

type configure struct {
    s shell
		f file
}

func (c configure) Name() string {
	return "configure"
}
/**
 * Execute logic for configure command
 */
func (c configure) Execute(args map[string]string) error {
	fmt.Println("configure codesketch", args)
	var baseUrl = args["baseUrl"]
	var version = args["version"]
	var installDirectory = args["installDirectory"]
	var target = fmt.Sprintf("%s/codesketch-%s", installDirectory, version)
  var serverName = args["serverName"]
	var swarmProvider = args["swarm"]
	var dc = c.evaluateOpenLDAPdc(serverName)
	var composeFiles = c.prepareComposeFiles(swarmProvider)

	c.downloadCodesketchPackage(fmt.Sprintf("%s/v%s.zip", baseUrl, version))
	c.unzipCodesketchPackage("/tmp/codesketch.zip", installDirectory)
	c.configureSwarmIfRequested(target, swarmProvider, serverName)
	c.createConfigurationFiles(target, serverName, dc, swarmProvider)

	fmt.Println("Pulling codesketch images")
	c.s.Execute("docker-compose", composeFiles, "pull")
	return nil
}

func (c configure) prepareComposeFiles(swarmProvider string)  {
	var answer = "-f docker-compose-nginx.yml -f docker-compose-codesketch.yml -f docker-compose-openldap.yml -f docker-compose-elk.yml"
	if len(swarmProvider) > 0 {
		answer = fmt.Sprintf("%s -f docker-compose-elk-swarm.yml -f docker-compose-openldap-swarm.yml -f docker-compose-nginx-swarm.yml -f docker-compose-codesketch-swarm.yml", answer)
	}
	return answer
}

func (c configure) createConfigurationFiles(target, serverName, dc, swarmProvider string) {
		var environment = []string{ fmt.Sprintf("SERVER_NAME=%s\n", serverName),
    	fmt.Sprintf("EMAIL=%s\n", ""),
    	fmt.Sprintf("LDAP_ORGANISATION=%s\n", serverName),
    	fmt.Sprintf("LDAP_DOMAIN=%s\n", serverName),
    	fmt.Sprintf("LDAP_BASEDN=%s\n", dc),
	    fmt.Sprintf("LDAP_ADMIN_PASSWORD=%s\n", "password"),
	    fmt.Sprintf("JENKINS_LDAP_BASEDN=%s\n", dc),
    	fmt.Sprintf("JENKINS_LDAP_MANAGER_DN=cn=admin,%s\n", dc),
    	fmt.Sprintf("JENKINS_LDAP_MANAGER_PASSWORD=%s\n", "password")}
		c.f.Write(fmt.Sprintf("%s/environment", target), environment)
		var address string
		var err error
		if len(swarmProvider) > 0 {
			address = c.s.Execute("docker-machine", "ip", "codesketch-swarm-master")
		} else {
			address, err = c.externalIP()
			check(err)
		}
		var env = []string{fmt.Sprintf("SERVER_NAME=%s\n", serverName),
    	fmt.Sprintf("LOGSTASH_HOST=%s\n", address),
	    fmt.Sprintf("PROXY_HOST=%s\n", address)}
    c.f.Write(fmt.Sprintf("%s/.env", target), env)
}

func (c configure) evaluateOpenLDAPdc(serverName string) string {
    var tmp = strings.Replace(serverName, ".", ",dc=", -1)
    return fmt.Sprintf("dc=%s", tmp)
}

func (c configure) configureSwarmIfRequested(target, swarm, serverName string) {
	if len(swarm) > 0 {
		fmt.Println("swarm configuration requested for provider", swarm)
        var cmd = fmt.Sprintf("%s/swarm/setup-%s", target, swarm)
        c.s.Execute(cmd, "2", serverName)
	} else {
		fmt.Println("swarm configuration not requested skipping it...")
	}
}

func (c configure) downloadCodesketchPackage(url string) {
	var fileName = "/tmp/codesketch.zip"
	output, err := os.Create(fileName)
	if err != nil {
		fmt.Println("unable to download", fileName, "-", err)
		return
	}
	defer output.Close()

	response, err := http.Get(url)
	if err != nil {
		fmt.Println("Error while downloading", url, "-", err)
		return
	}
	defer response.Body.Close()

	n, err := io.Copy(output, response.Body)
	if err != nil {
		fmt.Println("Error while downloading", url, "-", err)
		return
	}

	fmt.Println(n, "bytes downloaded.")
}

func (c configure) unzipCodesketchPackage(src, dest string) error {
    r, err := zip.OpenReader(src)
    if err != nil {
        return err
    }
    defer func() {
        if err := r.Close(); err != nil {
            panic(err)
        }
    }()

    os.MkdirAll(dest, 0755)

    // Closure to address file descriptors issue with all the deferred .Close() methods
    extractAndWriteFile := func(f *zip.File) error {
        rc, err := f.Open()
        if err != nil {
            return err
        }
        defer func() {
            if err := rc.Close(); err != nil {
                panic(err)
            }
        }()

        path := filepath.Join(dest, f.Name)

        if f.FileInfo().IsDir() {
            os.MkdirAll(path, f.Mode())
        } else {
            os.MkdirAll(filepath.Dir(path), f.Mode())
            f, err := os.OpenFile(path, os.O_WRONLY|os.O_CREATE|os.O_TRUNC, f.Mode())
            if err != nil {
                return err
            }
            defer func() {
                if err := f.Close(); err != nil {
                    panic(err)
                }
            }()

            _, err = io.Copy(f, rc)
            if err != nil {
                return err
            }
        }
        return nil
    }

    for _, f := range r.File {
        err := extractAndWriteFile(f)
        if err != nil {
            return err
        }
    }

    return nil
}

func (c configure) externalIP() (string, error) {
	ifaces, err := net.Interfaces()
	check(err)
	for _, iface := range ifaces {
		if iface.Flags&net.FlagUp == 0 {
			continue // interface down
		}
		if iface.Flags&net.FlagLoopback != 0 {
			continue // loopback interface
		}
		addrs, err := iface.Addrs()
		check(err)
		for _, addr := range addrs {
			var ip net.IP
			switch v := addr.(type) {
			case *net.IPNet:
				ip = v.IP
			case *net.IPAddr:
				ip = v.IP
			}
			if ip == nil || ip.IsLoopback() {
				continue
			}
			ip = ip.To4()
			if ip == nil {
				continue // not an ipv4 address
			}
			return ip.String(), nil
		}
	}
	return "", errors.New("are you connected to the network?")
}


func check(e error) {
    if e != nil {
        panic(e)
    }
}
