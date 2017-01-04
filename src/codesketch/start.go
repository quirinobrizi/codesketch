package main

import "fmt"

type start struct {
	s shell
}

func (s start) Name() string {
	return "start"
}

func (s start) Execute(args map[string]string) error {
	fmt.Printf("Start Args: %q", args)
	return nil
}
