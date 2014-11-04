#This cookbook is part of CodeIgnition's public cookbooks used for infrastructure management on amzon web services

-----
Please note that this cookbook is very specific to codeignition's infrastructure way of doing things
-----

##Opionated Stuff:
CodeIgnition's cookbooks are very opinionated in some ways

0. The source of truth for this cookbook is instance names in AWS
1. Our cookbooks don't use roles
2. These cookbooks heavily depend on databags
3. Most of the cookbooks leverage berkshelf pretty heavily
4. We assume that these aren't to be used anywhere else, please use it if you want, but don't expect us to fix the bugs
5. This is free as in freedom but nothing more..

##Pre-requisits

* ci-named databag for holding all attributes for your given environment
* by default we assume you are in global environment ( at CodeIgnition all Configuration Managment and Sytem services live in service environment)
* better to use berkshelf
* If you prefere to put it in specific environment, then fork this cookbook

##Usage

* edit the given databag with sample 
* use this cookbook by adding this to berksfile
```
cookbook 'bind_server', git: "https://github.com/codeignition/bind_server.git"
```
