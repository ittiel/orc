FROM python -m pip install psycopg2 as builder


# todo: separate builder, tester and application
ARG DATABASE_URL

WORKDIR /app

# copy sources
ADD src/* /app/
# install dependencies
RUN pip install -U pip setuptools && pip install pipenv
RUN python -m pip install psycopg2 psycopg2-binary
RUN pipenv install

# Establish the runtime user (with no password and no sudo)
# RUN useradd -m candidate
# RUN chown candidate /app/*
#
# USER candidate
RUN chmod 775 run_app.sh

CMD ["pipenv", "run", "./run_app.sh"]

##################################
# todo: enable after adding tests
# FROM builder as tester
# RUN python test

##################################
# todo: enable for lint
#FROM builder as tester
# ...