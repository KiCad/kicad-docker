# KiCad

This docker image is intended primarily for being able to use kicad-cli in CI applications.

These docker images are currently based on Debian bookworm.

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