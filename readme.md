
## How to Install

#### Langkah Pertama

Pastikan certificate SSL telah dimiliki dan dimasukan didalam satu folder yang sama dengan file installer. Pastikn penamaan file seperti berikut
```http
  ca_bundle1.crt certificate1.crt private1.key
```
```http
  ca_bundle2.crt certificate2.crt private2.key
```

Selanjutnya pindahkan kedalam folder **ProteksiCoraza**

#### Langkah Kedua
Clone Repository :
```http
  git clone https://github.com/blackabed/ProteksiCoraza
  cd ProteksiCoraza
```

Jalankan Command Berikut : 
```http
  sudo chmod +x WAF_Run.sh
```

Dilanjutkan dengan perintah :
```http
  sudo ./WAF_Run.sh
```

Akan muncul prompt untuk melakukan inputan 

`Domain for backend_service1` : Masukan domain dari server origins pertama (Contoh: www.coraza2.cloud)

`IP address for backend_service1` : Masukan IP Origins Server yang akan dilindungi (Contoh: 10.16.1.2)

`Domain for backend_service2` : Masukan domain dari server origins pertama (Contoh: www.coraza3.cloud)

`IP address for backend_service2` : Masukan IP Origins Server yang akan dilindungi (Contoh: 10.16.1.3)







