import requests
import json
import os
import shutil

arr = ["zh-Hans","en","zh-Hant","ja","fr","ko","de","ru","es","it","pt-BR","ar","hu","pl","cs","vi","th","id","tr","da","nl","hr","sv","mn"]

for ss in arr:
    la = ss
    if ss == "zh-Hans":
        la = "zh"
    if ss == "zh-Hant":
        la = "zh_tw"
    if ss == "pt-BR":
        la = "pt"
    if ss == "id":
        la = "ind"

    url = f'https://uniquehealth.lefuenergy.com/unique-app/web/system/lang/getListByAppType?appId=1&appType=2&lang={la}'
    r = requests.get(url, timeout=15)
    print(f"请求地址：{url}")
    
    try:
        json_obj = json.loads(r.text)
    except Exception as e:
        print(f"【解析失败】{ss} 错误：{e}")
        continue

    if "data" not in json_obj:
        print(f"【无data字段】{ss}")
        continue
        
    data_obj = json_obj['data']

    # 文件名
    file_name = f"{ss}.json"

    # =====重点：防止 IsADirectoryError 冲突=====
    if os.path.exists(file_name):
        if os.path.isdir(file_name):
            shutil.rmtree(file_name)

    # 格式化输出json，中文不乱码
    result_str = json.dumps(data_obj, ensure_ascii=False, indent=2)

    # with自动关闭文件，标准写法
    with open(file_name, 'w', encoding="utf-8") as f:
        f.write(result_str)

    print(f"✅ {file_name} 下载完成\n")