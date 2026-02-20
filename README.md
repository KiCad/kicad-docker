# KiCad

This docker image is intended primarily for being able to use kicad-cli in CI applications.

These docker images are currently based on Debian bookworm.

## Version Tags & Architectures


|Tag	 | Description | OS |
|--------| ------- | ------ |
|nightly | Build of latest master branch each night | Debian 13 Trixie
|nightly-full| nightly + includes 3d symbols| Debian 13 Trixie
|nightly-YYYYMM | Master branch built during the given YYYY-MM | Debian 13 Trixie
|9.0   	 | Always the latest stable 9.0 release | Debian 12 Bookworm
|9.0.x   | 9.0.x specific release | Debian 12 Bookworm
|8.0   	 | Always the latest stable 8.0 release | Debian 12 Bookworm
|8.0.x   | 8.0.x specific release | Debian 12 Bookworm

amd64 images are available by default for tags.

arm64 is available with the nightly tag and 9.0+ tags.

It is highly recommended you do not use the arch specific tags that may be visible in the repository list and instead a tag from the table above.


## Tag Policy
A new docker image will be generated for each official release.

A major.minor.patch tag will be locked to that specific release:
`kicad/kicad:7.0.0`

Meanwhile a major.minor tag will be updated over time to reflect the latest patch release at time of pull:
`kicad/kicad:7.0`

Additionally nightly builds will be avaiable at the tag:
`kicad/kicad:nightly`

Due to the rolling nature of nightlies, there wll be a once a month generated image to have some limited 
ability to stick to a nightly build but minimize disk space overhead of storing 365 docker images, tags will look like:
`kicad/kicad:6.99-202212`

## Image Retention Policy
All stable release images will be retained indefinitely (at best effort). 

Nightly monthly tagged releases will be kept at best effort for up to a year after the next major release.

Users are encouraged to move to a stable release image when able.

## GitLab CI Usage
KI_BUILD_TYPE=daily
              monthly
              release