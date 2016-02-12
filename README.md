# image-builder-odroid-c1
[![Join the chat at https://gitter.im/hypriot/talk](https://badges.gitter.im/hypriot/talk.svg)](https://gitter.im/hypriot/talk?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)
[![Build Status](https://travis-ci.org/hypriot/image-builder-odroid-c1.svg)](https://travis-ci.org/hypriot/image-builder-odroid-c1)


**Disclaimer:** This is work in progress and not yet finished. But if you want to help us and give feedback for the upcoming HypriotOS please read on. You can find the latest SD-Card image in the [GitHub releases page](https://github.com/hypriot/image-builder-odroid-c1/releases).

This repo builds the SD card image with HypriotOS for the ODROID C1 board. To build this SD-Card image we have to

 * take the files for the root filesystem from [`os-rootfs`](https://github.com/hypriot/os-rootfs)
 * add Hypriot's Debian repos
 * install the ODROID kernel
 * install Docker tools Docker Engine, Docker Compose and Docker Machine

Here is an example how all the GitHub repos play together:

![Architecture](http://blog.hypriot.com/images/hypriotos-xxx/hypriotos_buildpipeline.jpg)

## Contributing

You can contribute to this repo by forking it and sending us pull requests. Feedback is always welcome!

You can build the SD-Card image locally with Vagrant.

### Setting up build environment
Make sure you have [vagrant](https://docs.vagrantup.com/v2/installation/) and [docker-machine](https://docs.docker.com/machine/install-machine/) installed. Then run the following command to create the Vagrant box and the Docker Machine connection. The Vagrant box is needed as a vanilla boot2docker VM is not able to run guestfish inside.

```bash
make docker-machine
```

Now set the Docker environments to this new docker machine:

```bash
eval $(docker-machine env image-builder-odroid-c1)
```

### Build the SD-Card image

From here you can just make the SD-Card image. The output will be written and compressed to `sd-card-odroid-c1-dirty.img.zip`.

```bash
make sd-image
```

### Run Serverspec tests

To test the compressed SD-Card image with [Serverspec](http://serverspec.org) just run the following command. It will expand the SD-Card image in a Docker container and run the Serverspec tests in `builder/test/` folder against it.

```bash
make test
```

### Run integration tests

Now flash the SD-Card image and boot up a ODROID C1. Run the [Serverspec](http://serverspec.org) integration tests in `builder/test-integration/` folder against your ODROID C1. Set the environment variable `BOARD` to the IP address or host name of your running ODROID C1.

```bash
flash sd-card-odroid-c1-dirty.img.zip
BOARD=black-pearl.local make test-integration
```

This test works with any Docker Machine, so you do not need to create the Vagrant box.

## Deployment

For maintainers of this project you can release a new version and deploy the SD-Card image to GitHub releases with

```bash
TAG=v0.0.1 make tag
```

After that open the GitHub release of this version and fill it with relevant changes and links to resolved issues.

## License

MIT - see the [LICENSE](./LICENSE) file for details.
