# Proiect IDP - Stock Trading Platfrom

## Introducere
Scopul proiectului este de a realiza o aplicație web folosind Docker, ce va permite utilizatorilor autentificați sa tranzacționeze acțiuni listate pe piețele bursiere. Platforma oferă clienților accesul la pretul in timp real despre cotațiile bursiere si permite tranzacționarea acțiunilor prin plasarea ordinelor de cumpărare sau de vânzare, ce vor fi executate automat de către aplicație când condițiile impuse sunt îndeplinite.


## Arhitectura aplicației
Aplicatia propusa prezinta o arhitectura modulara, bazate pe mai multe containere. In figura de mai jos se poate observa arhitectura propusa.

![arhitectura](/img/arhitectura.png)

## Descrierea componentelor aplicației
- KONG API Gateway – KONG va fi folosit pentru a expune aplicația clienților. Serviciul va fi expus la portul 80 al serverului pe care aplicatia ruleaza. Folosind KONG vom expune public rutele pentru autentificare (prefixate cu `/auth`), rutele pentru platforma de trading (prefixate cu `/platform`) si ruta pentru serviciul Adminer (`/adminer`).

- Auth Service – Componenta de autentificare si autorizare va fi folosita pentru a gestiona conturile clienților din baza de date, dar si pentru accesul acestora la platforma de tranzacționare. Serviciul oferă următoarele funcționalități:
    - REGISTER – permite utilizatorilor sa își creeze un cont pe platforma si îl stochează in baza de date; inregistrarea se va face pe ruta `/register` cu o cerere de tip POST cu parametrii `client_id` si `client_secret`;
    - LOG-IN – permite utilizatorilor sa se conecteze cu datele proprii si generează un jeton JWT pentru accesul la platforma de tranzacționare; autentificarea se va face pe ruta `/login` cu o cerere de tip POST cu parametrii `client_id` si `client_secret`;
    - VERIFY – verifica valabilitatea jetonului JWT furnizat; ruta `/verify` va fi accesata de catre serviciul Trading Service printr-o cerere de tip POST cu token-ul JWT trimis in header-ul de autentificare
    - LOG-OUT – invalidează jetonul JWT al utilizatorului; operatia se va face trimitand o cerere de tip POST pe ruta `/logout` cu token-ul JWT trimis in header-ul de autentificare

- Stock Trading Service – Componenta principala a aplicației, responsabila pentru partea de „business logic”. Serviciul va permite accesul clienților, după verificarea jetonului JWT, la următoarele funcționalități:
    - GET QUOTES – obține ultimele date disponibile despre un indice, datele includ pretul acestuia si informatii despre ordinele plasate; functionalitatea este disponibila printr-o cerere de tipul GET la ruta `/quotes/<symbol>` unde `<symbol>` este simbolul folosind pentru tranzactionare.
    - PLACE ORDER – creează un nou ordin pentru utilizatorul curent; functionalitatea este disponibila printr-o cerere de tipul POST la una dintre  rutele `/quotes/<symbol>/buy` sau `quotes/<symbol>/sell` unde `<symbol>` este simbolul folosind pentru tranzactionare. Continutul cererii va trebui sa contina cantitatea (`quantity`) si pretul (`price`), dar si un token de autentificare valid in header-ul de autentificare.
    - UPDATE ORDER – modifica un ordin creat anterior de utilizatorul curent; functionalitatea este disponibila printr-o cerere de tipul PUT la ruta `/orders/<id>` unde `<id>` este id-ul ordinului ce se doreste a fi modificat. Continutul cererii va trebui sa contina cantitatea (`quantity`) si pretul (`price`), dar si un token de autentificare valid in header-ul de autentificare.
    - REMOVE ORDER – anulează un ordin plasat de utilizatorul curent; functionalitatea este disponibila printr-o cerere de tipul DELETE la ruta `/orders/<id>` unde `<id>` este id-ul ordinului ce se doreste a fi sters. Continutul cererii va trebui sa contina un token de autentificare valid in header-ul de autentificare.
    - PROCESS ORDER - trimite serviciului de management al portofoliului informatiile de actualizare dupa ce o cerere a fost executata de serviciul de management al ordinelor; functionalitatea este disponibila printr-o cerere de tipul POST la ruta `/orders/process`. Continutul cererii va trebui sa contina un secret al serviciului de procesare a ordinelor (`secret`), id-urile clientilor (`id_client`, `from_id_client`), tipul (`type`), simbolul (`symbol`), cantitatea (`quantity`) si pretul (`pretul`).
    - GET PORTFOLIO – afișează informații despre portofoliul utilizatorului; functionalitatea este disponibila printr-o cerere de tipul GET la ruta `/portfolio`. Continutul cererii va trebui sa contina un token de autentificare valid in header-ul de autentificare.
    - DEPOSIT FUNDS – alimentează componenta cash prin transfer bancar; functionalitatea este disponibila printr-o cerere de tipul POST la ruta `/deposit`. Continutul cererii va trebui sa contina suma (`amount`), dar si un token de autentificare valid in header-ul de autentificare.
    - WITHDRAW FUNDS - retrage fonduri din componenta cash prin transfer bancar; functionalitatea este disponibila printr-o cerere de tipul POST la ruta `/withdraw`. Continutul cererii va trebui sa contina suma (`amount`), dar si un token de autentificare valid in header-ul de autentificare.
- Market Data Service – Componenta auxiliara a aplicației, responsabila pentru obținerea datelor in timp real a unui simbol bursier de pe platforma Yahoo! Finance. La nivelul aplicatiei, componenta este integrata in servicul Stock Trading Platform

- Portfolio Management Service – Componenta responsabila pentru interacțiunea cu baza de date Portfolios DB; prezinta rute pentru obtinerea portofoliului unui client (`GET /portfolio/<id>`) si pentru actualizarea portofoliului unui client (`PUT /portfolio/<id>`).

- Order Management Service – Componenta responsabila pentru interacțiunea cu baza de date Orders DB. Pe lângă aceasta funcționalitate, componenta va executa ordinele plasate daca o pereche de ordine (cumpărare, vânzare) cu același preț este găsita in baza de date. Aceasta verificare se va face după fiecare introducere a unui nou ordin in baza de date. Serviciul prezinta rute pentru adaugarea ordinelor (`POST /orders`), obtinerea ordinelor dupa id ordin (`GET /orders/<id>`) si dupa id-ul clientului (`GET /orders/client/<id>`), actualizarea ordinelor dupa id (`PUT /orders/<id>`), stergerea ordinelor dupa id (`DELETE /orders/<id>`) si obtinerea adancimii pentru un simbol (`GET /depth/<symbol`>).

- Postgres - Sistemul de baze de date va contine 4 utilizatori (admin, auth_service, portfolios_service, orders_service) si 3 baze de date:
    - Auth DB – conține 2 tabele: users - stochează datele de autentificare ale clienților platformei (nume utilizator, parola criptata); expired_tokens – stochează datele despre jetoanele JWT expirate.
    - Portfolios DB – Conține o tabela pentru fiecare client in care sunt stocate informații despre acțiunile deținute si componenta lichida.
    - Orders DB – Conține informații despre toate ordinele plasate de către utilizatori in ultimele 10 de zile. Baza de date contine 2 tabele: una pentru ordinele plasate, una pentru cele executate.Informatiile includ: identificatorul utilizatorului, identificatorul celui de-al doilea client (daca este cazul), valoarea ordinului, simbolul actiunii, cantitatea, data plasarii sau data executarii.
- Portainer + Agent – Serviciu folosit pentru gestiunea din UI a clusterului. Serviciul poate fi accesat pe portul 9000.
- Adminer – Utilitar folosit pentru gestiunea bazelor de date.
- Prometheus – Sistem de monitorizare folosit pentru a obtine metrici de la serviciul de Kong.
- Loki – Sistem de logging, ce obtine log-urile trimise catre driver-ul de Loki de catre docker
- Grafana – Sistem de vizualizare metrici si log-uri. Prezinta doua dashboard-uri: primul dashboard este dashboard-ul default de Kong si afiseaza metricile obtinute de la serviciul de Kong, al doilea dashboard prezinta mai multe ecrane pentru vizualizarea mesajelor de log provenite de la serviciile de autentificare si de la platforma. Serviciul este disponibil pe portul 3000. 

## Rulare folosind Play With Docker

Pentru rularea cu [Play With Docker](https://labs.play-with-docker.com/) vom initializa un Swarm cu 1 manager si 2 workeri.
Pe nodul manager vom incarca repository-ul de configurare si vom introduce comanda `docker login` pentru a ne conecta la registrul Gitlab cu imagini.
```
docker login gitlab.cs.pub.ro:5050
```
Pe fiecare dintre cele trei noduri vom instala plugin-ul de logare folosind Loki.
```
docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
```

Vom modifica daemon-ul de Docker pe fiecare nod astfel incat logarea sa se faca folosind driver-ul de Loki instalat anterior. O configuratie posibila pentru fisierul `/etc/docker/daemon.json` poate fi gasita in fisierul `/pwd-init/daemon.json`:
```
{
    "experimental": true,
    "debug": false,
    "log-driver": "loki",
    "log-opts": {
      "loki-url": "http://127.0.0.1:3100/loki/api/v1/push"
    },
    "log-level": "info",
    "insecure-registries": ["127.0.0.1"],
    "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"],
    "tls": false,
    "tlscacert": "",
    "tlscert": "",
    "tlskey": ""
}
```

In final, vom restarta serviciul de Docker pe fiecare nod:
```
kill -9 `pgrep dockerd`; dockerd > /docker.log 2>&1 &
```

## Testare

Pentru testarea rutelor expuse catre utilizatori folosind serviciul Kong, se poate folosi fisierul `/tests/trading-platform.postman_collection.json` ce contine o colectie de teste pentru aplicatia Postman. Folosind variabile de mediu utilizatorul poate seta jetoanele clientilor. `TOKENn`, si adresa host-ului pe care ruleaza aplicatia, `HOSTNAME`.