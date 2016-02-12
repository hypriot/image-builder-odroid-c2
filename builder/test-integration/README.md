# HypriotOS serverspec tests

## Install Serverspec

You need `ruby` and `bundle` installed. Then you can install the dependencies locally with:
```bash
bundle install
```

TODO: describe how to install rspec/rake


## Run tests

### Basic SD image tests

```bash
BOARD=black-pearl.local bin/rspec spec/hypriotos-image
```

### Full Docker tests

```
BOARD=black-pearl.local bin/rspec spec/hypriotos-docker
```
