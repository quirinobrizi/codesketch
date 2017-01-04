package main

import (
	"os/exec"
	"syscall"
	"fmt"
	"strings"
	"os"
  "bufio"
	"bytes"
)

type shell struct {
}

func (s shell) Execute(command string, args ...string) string {
	cmd := exec.Command(command, args...)
	var waitStatus syscall.WaitStatus
	var out bytes.Buffer
	cmd.Stdout = &out
	var answer string
	if err := cmd.Run(); err != nil {
	  printError(err)
	  // Did the command fail because of an unsuccessful exit code
	  if exitError, ok := err.(*exec.ExitError); ok {
	    waitStatus = exitError.Sys().(syscall.WaitStatus)
	    printOutput([]byte(fmt.Sprintf("%d", waitStatus.ExitStatus())))
	  }
		answer = ""
	} else {
	  // Command was successful
	  waitStatus = cmd.ProcessState.Sys().(syscall.WaitStatus)
	  printOutput([]byte(fmt.Sprintf("%d", waitStatus.ExitStatus())))
		answer = out.String()
	}
	return answer
}

func printCommand(cmd *exec.Cmd) {
  fmt.Printf("==> Executing: %s\n", strings.Join(cmd.Args, " "))
}

func printError(err error) {
  if err != nil {
    os.Stderr.WriteString(fmt.Sprintf("==> Error: %s\n", err.Error()))
  }
}

func printOutput(outs []byte) {
  if len(outs) > 0 {
    fmt.Printf("==> Output: %s\n", string(outs))
  }
}

type file struct {}

/**
 * Write the provided content to the file at the specified path.
 */
func (f file) Write(path string, content []string)  {
	fl, err := os.Create(path)
	check(err)
	defer fl.Close()
	w := bufio.NewWriter(fl)
	for k := range content {
		w.WriteString(content[k])
	}
	w.Flush()
}
