# Base PHP FPM Dockerfile 

This is **Dockerfile**, the DoSomething.org base image for services. It's our single "source of builds" for developers.

To learn more about: # TODO

### Build

`docker build -f Dockerfile -t dosomething/infrastructure:php_base .`  

### Optimization

We must consider to build tighter images - on alpine

### Security 
We take security very seriously. Any vulnerabilities in Northstar should be reported to [security@dosomething.org](mailto:security@dosomething.org),
and will be promptly addressed. Thank you for taking the time to responsibly disclose any issues you find.

### License

&copy;2019 DoSomething.org. Northstar is free software, and may be redistributed under the terms specified
in the [LICENSE](https://github.com/DoSomething/northstar/blob/dev/LICENSE) file. The name and logo for
DoSomething.org are trademarks of Do Something, Inc and may not be used without permission.

