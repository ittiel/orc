FROM python:3.8 as builder

# todo: remove root user
# todo: separate builder, tester and application
ARG DATABASE_URL
WORKDIR /app

# copy sources
ADD src/* .
# install dependencies
RUN pip install -U pip setuptools && pip install pipenv

RUN pipenv install

RUN chmod 775 run_app.sh

CMD ["pipenv", "run", "./run_app.sh"]

# todo: enable after adding tests
# FROM builder as tester
# RUN python test
