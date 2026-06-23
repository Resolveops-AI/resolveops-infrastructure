lines = open('variables.tf', 'r', encoding='utf-8', errors='ignore').readlines()
with open('variables.tf', 'w', encoding='utf-8') as f:
    f.writelines(lines[:246])
    f.write('\nvariable "jumpbox_admin_password" {\n  type    = string\n  default = "resolveopsadmin@123"\n}\n')
