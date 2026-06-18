import re

dart_file = r'c:\Users\user\Nata\Project\Website-Sespima\Mobile\sespimma-mobile\lib\core\constants\reward_punishment_data.dart'
with open(dart_file, 'r', encoding='utf-8') as f:
    content = f.read()

count = 1
def replace_rewards(match):
    global count
    res = f"id: '{count}',"
    count += 1
    return res

content = re.sub(r"id:\s*'R_[A-Z]+_\d+',", replace_rewards, content)

pun_count = 1
def replace_punishments(match):
    global pun_count
    res = f"id: '{pun_count}',"
    pun_count += 1
    return res

content = re.sub(r"id:\s*'P_[A-Z]+_\d+',", replace_punishments, content)

with open(dart_file, 'w', encoding='utf-8') as f:
    f.write(content)

print("Updated dart file IDs successfully")
