# Ruby on Rails example

This basic project shows how to use the Ruby SDK in a Rails (2.7.x) application.

You can build the docker image with

```bash
docker build -t rails-example .
```

Then run it with

```bash
export FF_API_KEY=<your server SDK key>
docker run -e FF_API_KEY=$FF_API_KEY -p 3000:3000 --rm rails-example
```

Server can be accessed via your web browser at

http://localhost:3000/

When you toggle a flag on https://app.harness.io it will be logged in the console output of the container. Since this is a server SDK you need to refresh the page in the browser to see the HTML update.
