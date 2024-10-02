use std::fs::{self, File};
use std::io::{self, Write};
use std::process::Command;
use std::path::Path;

const DIR: &str = "/path/to/folder";
const LOGFILE: &str = "corruption_log.txt";
const FORMATS: [&str; 5] = ["mp4", "mkv", "avi", "mov", "flv"];

fn main() -> io::Result<()> {
    let mut log_file = File::create(LOGFILE)?;

    for entry in fs::read_dir(DIR)? {
        let entry = entry?;
        let path = entry.path();
        if path.is_file() && is_supported_format(&path) {
            let filename = path.file_name().unwrap().to_str().unwrap();
            writeln!(log_file, "Filename: {}", filename)?;
            check_corruption(filename, &mut log_file)?;
        }
    }

    writeln!(log_file, "Corruption check completed. Results are logged in {}", LOGFILE)?;
    Ok(())
}

fn is_supported_format(path: &Path) -> bool {
    if let Some(ext) = path.extension() {
        FORMATS.contains(&ext.to_str().unwrap())
    } else {
        false
    }
}

fn check_corruption(file: &str, log_file: &mut File) -> io::Result<()> {
    let output = Command::new("docker")
        .args(&["run", "--rm", "-v", &format!("{}:/videos", DIR), "linuxserver/ffmpeg:latest", "-v", "info", "-i", &format!("/videos/{}", file), "-f", "null", "-"])
        .output()?;

    if !output.status.success() {
        writeln!(log_file, "Corruption detected in: {}", file)?;
        writeln!(log_file, "Error message: {}", String::from_utf8_lossy(&output.stderr))?;
    } else {
        writeln!(log_file, "No corruption detected in: {}", file)?;
    }

    Ok(())
}
