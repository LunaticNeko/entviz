#!/usr/bin/python

import web
import ConfigParser
import json

config_file = 'config.ini'

config_file_db_section = 'db'

cp = ConfigParser.SafeConfigParser()
cp.read(config_file)

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
        allowed_columns = ['id', 'name', 'city', 'state', 'country']
        query = dict(web.input())
        results = db.select('domain', where=compose_where(allowed_columns, dict(web.input())))
        web.header('Content-Type', 'application/json')
        return json.dumps({'data': [x for x in results]})

def compose_where(columns, query):
    query_content = []
    for column in columns:
        if column in query:
            query_content.append("%s='%s'" % (column, query[column]))
    return ' AND '.join(query_content)


if __name__ == "__main__":
    app = web.application(urls, globals())
    app.run()
