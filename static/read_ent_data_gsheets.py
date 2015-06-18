import json
import gspread
from oauth2client.client import SignedJwtAssertionCredentials

json_key = json.load(open('pragma-ent-viz-359e7e1c5c80.json'))
scope = ['https://spreadsheets.google.com/feeds']

credentials = SignedJwtAssertionCredentials(json_key['client_email'], json_key['private_key'], scope)

gc = gspread.authorize(credentials)

print dir(gc)

all_wk = gc.openall()

print all_wk

#wks = gc.open('ENT_swtich_list')
#wks = gc.open("Ingress Stat Tracking")
#wks = gc.open_by_key('1-4r_Pk4i_lyFifQp9fa4tSbEr9ijf0H57V1zIgtxqpE')
