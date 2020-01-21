require '.\teams-lib.rb'

hook_url = 'https://outlook.office.com/webhook/715f4298-9d6c-45ad-969e-19cb20e10c92@33f00146-6fcc-49e9-b568-7896b3069d44/IncomingWebhook/ef5f36a00cf8463e89884fd9a50d33b9/bd56cfd5-1a19-435f-95b6-f70c1800d7f0'

teams = Teams.new(hook_url)
teams.post(
	bot: 'Bot Name',
	text: 'Hello, World!'
)
