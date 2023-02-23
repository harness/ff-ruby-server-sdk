FROM ruby:2.7.7
RUN apt-get update && apt-get install -y build-essential nodejs
RUN mkdir -p /app
WORKDIR /app
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && bundle install --jobs 10 --retry 3
COPY . ./
EXPOSE 3000
CMD ["rails", "s", "-b", "0.0.0.0"]
