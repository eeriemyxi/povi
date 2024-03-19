# Povi
A dictionary for your terminal. This project is identical to my other project, [novi](https://github.com/eeriemyxi/novi). 
But it is faster because it is written in Nim.
![](https://i.imgur.com/ob6mBef.png)

# Installation
## First Method
You can download pre-compiled amd64 binaries for Windows and Linux from the [release page](https://github.com/eeriemyxi/povi/releases/latest) of the GitHub mirror of this repository.
## Second Method
Install Nim and Nimble.
```shell
git clone --branch main --depth 1 <REPO URL> povi
cd povi
nimble install
```

# Command-line Arguments
```
usage: povi [--debug] [-V] [words ...]

positional arguments:
  words          Words to search. You can specify multiple words by splitting
                 them by whitespace.

options:
  --debug        Enable debug logs.
  -V, --version  Show program version.
```

# License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

* * *

Feel free to enhance Povi according to your needs and contribute back to the project! If you encounter any issues or have suggestions for improvement, please open an issue on the repository. Thank you for using Povi!
