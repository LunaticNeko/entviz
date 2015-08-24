#!/usr/bin/python

import web
import ConfigParser
import json
import logging

config_file = 'config.ini'

config_file_db_section = 'db'

cp = ConfigParser.SafeConfigParser()
cp.read(config_file)

logger = logging.getLogger()
handler = logging.StreamHandler()
formatter = logging.Formatter('%(asctime)s %(levelname)-8s %(message)s')
handler.setFormatter(formatter)
logger.addHandler(handler)
logger.setLevel(logging.DEBUG)

#TODO: support postgres & sqlite
db = web.database(dbn='mysql',
        db = cp.get(config_file_db_section, 'dbname'),
        user = cp.get(config_file_db_section, 'username'),
        pw = cp.get(config_file_db_section, 'password')
        )

urls = (
    '/', 'index',
    '/switch', 'switch_all',
    '/switch/(.+)', 'switch_by_dpid',
    '/link', 'link_all',
    '/link/(.+)/(.+)', 'link_by_dpid',
    '/domain', 'domain',
    '/domain/(.+)', 'domain',
    '/domain/id/(.+)', 'domain_by_id'
)

class index:
    def GET(self):
        raise web.notfound()

class switch_all:
    def GET(self):
        results = db.select('switch')
        web.header('Content-Type', 'application/json')
        return json.dumps([x for x in results])

class domain:
    def GET(self):
        allowed_columns = {'id', 'name', 'city', 'state', 'country'}
        validate_query_fields(allowed_columns, dict(web.input()))
        (q_vars, q_where) = vars_and_where(allowed_columns, dict(web.input()))
        try:
            results = db.select('domain', q_vars, where=q_where).list()
        except Exception as e:
            logger.exception(e)
            return json.dumps({'errors': ['malformed query syntax']})
        web.header('Content-Type', 'application/json')
        if len(results) == 0:
            return json.dumps({'data': [], 'warnings': ['query returned no results']})
        else:
            return json.dumps({'data': [x for x in results]})

# UTILS: TODO: Move these into a separate file

class ColumnNotAllowedError(Exception):
    def __init__(self, value):
        self.value = value
    def __str__(self):
        return repr(self.value)

def validate_query_fields(allowed_columns, query):
    if not all([column in allowed_columns for column in query]):
        raise ColumnNotAllowedError(set(query.keys()) - allowed_columns)
    else:
        return True

def vars_and_where(columns, query):
    return (filter_dict(columns, query), compose_where(columns, query))

def filter_dict(columns, query):
    return {column: query[column] for column in columns if column in query}

def compose_where(columns, query):
    query_content = []
    for column in columns:
        if column in query:
            query_content.append("%s=$%s" % (column, column))
    return ' AND '.join(query_content)


if __name__ == "__main__":
    logger.info('Welcome to Summoner\'s Rift!')
    app = web.application(urls, globals())
    app.run()
