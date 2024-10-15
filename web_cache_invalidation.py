import json

# Path to the web root
webRoot = './build/web'
# Locations of the Web application files we are going to update
indexHtmlPath = f'{webRoot}/index.html'
flutterJsPath = f'{webRoot}/flutter.js'
versionJsonPath = f'{webRoot}/version.json'

# Compose app version by adding build_number
with open(versionJsonPath, 'r') as versionJsonFile:
    versionJson = json.load(versionJsonFile)
appVersion = f"{versionJson['version']}b{versionJson['build_number']}".strip()

# Update flutter.js file by specifying app version to the main.dart.js
with open(flutterJsPath, 'r') as flutterJsFile:
    flutterJsContent = flutterJsFile.read()
flutterJsReplaced = flutterJsContent.replace('main.dart.js', f'main.dart.js?{appVersion}')
with open(flutterJsPath, 'w') as flutterJsFile:
    flutterJsFile.write(flutterJsReplaced)

# Update index.html file by specifying app version to the flutter.js file
with open(indexHtmlPath, 'r') as indexHtmlFile:
    indexHtml = indexHtmlFile.read()
indexHtmlReplaced = indexHtml.replace('"flutter.js"', f'"flutter.js?{appVersion}"')
with open(indexHtmlPath, 'w') as indexHtmlFile:
    indexHtmlFile.write(indexHtmlReplaced)