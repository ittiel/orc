import os
basedir = os.path.abspath(os.path.dirname(__file__))

class Config:
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL', f'postgres://{os.path.join(basedir, "app.db")}')
    #SQLALCHEMY_DATABASE_URI = 'postgres://postgres:mypassword@0.0.0.0:5432'
    SQLALCHEMY_TRACK_MODIFICATIONS = False
