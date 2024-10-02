package main

import (
    "fmt"
    "io/ioutil"
    "log"
    "os"
    "os/exec"
    "path/filepath"
    "strings"
)

const (
    dir     = "/path/to/folder"
    logFile = "corruption_log.txt"
)

var formats = []string{"mp4", "mkv", "avi", "mov", "flv"}

func main() {
    f, err := os.Create(logFile)
    if err != nil {
        log.Fatal(err)
    }
    defer f.Close()

    files, err := ioutil.ReadDir(dir)
    if err != nil {
        log.Fatal(err)
    }

    for _, file := range files {
        if !file.IsDir() && isSupportedFormat(file.Name()) {
            fmt.Fprintf(f, "Filename: %s\n", file.Name())
            checkCorruption(file.Name(), f)
        }
    }

    fmt.Fprintf(f, "Corruption check completed. Results are logged in %s.\n", logFile)
}

func isSupportedFormat(filename string) bool {
    ext := strings.ToLower(filepath.Ext(filename))
    for _, format := range formats {
        if ext == "."+format {
            return true
        }
    }
    return false
}

func checkCorruption(file string, f *os.File) {
    cmd := exec.Command("docker", "run", "--rm", "-v", fmt.Sprintf("%s:/videos", dir), "linuxserver/ffmpeg:latest", "-v", "info", "-i", fmt.Sprintf("/videos/%s", file), "-f", "null", "-")
    output, err := cmd.CombinedOutput()
    if err != nil {
        fmt.Fprintf(f, "Corruption detected in: %s\n", file)
        fmt.Fprintf(f, "Error message: %s\n", string(output))
    } else {
        fmt.Fprintf(f, "No corruption detected in: %s\n", file)
    }
}
