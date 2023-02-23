# Ruby on Rails example

This basic project shows how to use the Ruby SDK in a Rails (2.7.x) application.

### Build the docker image

```bash
docker build -t rails-example .
```

### Run docker image

```bash
export FF_API_KEY=<your server SDK key>
docker run -e FF_API_KEY=$FF_API_KEY -p 3000:3000 --rm rails-example
```

### Access web server

http://localhost:3000/

When you toggle a flag on https://app.harness.io it will be logged in the console output of the container. Since this is a server SDK you need to refresh the page in the browser to see the HTML update.


### Main files

[Controller](app/controllers/example_controller.rb)

[View](app/views/example/index.html.erb)

[Helper](app/helpers/example_helper.rb)
