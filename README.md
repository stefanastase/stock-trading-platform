# IDP Project - Stock Trading Platfrom

## Overview
The aim of the project is to develop a web application which would allow authenticated users to trade stocks of publicly traded companies. The platform will offer customers real-time stock prices and will allow trading stocks by placing buy/sell orders, which are automatically fulfilled at the earliest possible time. The application will be continarized using Docker.

## Arhitecture
The proposed architecture is based on multiple microservices and databases. Below, a diagram of the proposed architecture can be seen

![arhitectura](/img/arhitectura.png)

## Component description
- **KONG API Gateway** – KONG is used to expose the application to customers. The service will be exposed on port 80 of the host running the application. Using KONG, authentication endpoints   (prefixed with `/auth`), trading platform endpoints (prefixed with `/platform`) and the Adminer endpoint (`/adminer`) will be exposed.

- **Auth Service** – AuthN and AuthZ component, used for managing the customer accounts stored in the database and for validating customer requests to the trading platform. The service allows the following operations:
    - *REGISTER* – allows customers to create an account and stores the account in the database; to register, customers have to send a POST request to the `/register` endpoint with two parameters:  `client_id` and `client_secret`;
    - *LOG-IN* – allows customers to log-in with their credentials and generates a JWT for accesing the trading platform; to log-in, customers have to send a POST request to the `/login` endpoint with two parameters: `client_id` and `client_secret`;
    - *VERIFY* – verifies the provided JWT token; to verify a token, the Stock Trading Service will send a POST request to the endpoint `/verify` with the JWT token included in the authentication header;
    - *LOG-OUT* – invalidates the JWT token of the user; to invalidate a token, a POST request to the `/logout` endpoint will be send, with the token included in the authentication header.

- **Stock Trading Service** – The core component of the application, responsible for "business logic". The service allows customers (after validating the JWT token) to:
    - *GET QUOTES* – fetches the latest information about a company, i.e the price on the market and the number of placed orders; to get the quotes, customers have to send a GET request to the `/quotes/<symbol>` endpoint, where `<symbol>` is the symbol used on the market for the company.
    - *PLACE ORDER* – creates a new order for the authenticated user; to place an order, the user has to send a POST request to one of the following endpoints: `/quotes/<symbol>/buy`, `quotes/<symbol>/sell`, where `<symbol>` is the symbol used on the market for the company. The request should contain the `quantity`, the `price` and a JWT token in the authentication header.
    - *UPDATE ORDER* – updates an existing order placed by the authenticated user; to update an orderm, the user has to send a PUT request to the  `/orders/<id>` endpoint, where `<id>` is the id of the order that will be modified. The request should contain the `quantity`, the `price` and a JWT token in the authentication header.
    - *REMOVE ORDER* – deletes an order placed by the authenticated user; to delete an order, the user has to send a DELETE request to the `/orders/<id>` endpoint, where `<id>` is the id of the order that will be removed. The request should contain a JWT token in the authentication header.
    - *PROCESS ORDER* - sends an update request to the portfolio management service after an order has been executed by the order management service; to process an order, a POST request is sent to the `/orders/process` endpoint. The request contains a `secret`, known by the order processing service, the ids of the clients that take part in a transaction (`id_client`, `from_id_client`), the `type` of the transaction (buy or sell), the `symbol`, the `quantity`, the `price`.
    - *GET PORTFOLIO* – displays information about the portfolio of the authenticated user; to display the details, the user has to send a GET request to the `/portfolio` endpoint. The request should contain a JWT token in the authentication header.
    - *DEPOSIT FUNDS* – increases the amount of funds available in the portfolio of the authenticated user; to deposit funds, the user sends a POST request to the `/deposit` endpoint. The request should include in its payload the `amount` of funds deposited and a JWT token in the authentication header.
    - *WITHDRAW FUNDS* - decreases the amount of funds available in the portfolio of the authenticated user; to withdraw funds, the user sends a POST request to the `/withdraw` endpoint. The request should include in its payload the `amount` of withdrawn funds and a JWT token in the authentication header.
      
- **Market Data Service** – Auxiliary component of the application, responsible for fetching real-time stock data from Yahoo! Finance. At the application level, the component is defined as a module of the Stock Trading Platform.

- **Portfolio Management Service** – Component responsible for interacting with the Portfolios DB; exposes endpoint for fetching portfolio information for a customer (`GET /portfolio/<id>`) and for updating the portfolio of a customer (`PUT /portfolio/<id>`).

- **Order Management Service** – Component responsible for interacting with the Orders DB. Beside this, the component is responsible for executing orders if a buy-sell pair of orders exists in the database. The check for pairs will take place every time a new order gets added to the database. The service exposes endpoint for adding orders (`POST /orders`), fetching order details using their id (`GET /orders/<id>`) or the customer id (`GET /orders/client/<id>`), updating orders using the id (`PUT /orders/<id>`), deleting orders using the id (`DELETE /orders/<id>`) and fetching the depth information for a symbol (`GET /depth/<symbol`>).

- **Postgres** - The DBMS contains 4 users (admin, auth_service, portfolios_service, orders_service) and 3 databases:
    - *Auth DB* – contains 2 tables: `users` - used for storing the data for registered users (usernames, encrypted passsword); `expired_tokens` – used for storing a list of invalidated JWT tokens.
    - *Portfolios DB* – Contains a table for each customer where data about the components of their portfolios is stored.
    - *Orders DB* – Contains information of all orders place in the last 10 days. The DB is made up of 2 tables: one for placed orders, one for executed orders. The stored data includes: the id of the first user, the id of the second user (if the second user exists), the value of the order, the symbol of the traded stock, the quantity, the creation date sau the execution date.
- **Portainer + Agent** – Service responsbile for managing the application cluster using a UI. The service is available on port 9000.
- **Adminer** – Component used for managing the databases.
- **Prometheus** – Monitoring system used for gathering metrics from Kong.
- **Loki** – Logging system, gathering logs sent by Docker to the Loki driver.
- **Grafana** – Service for visualization of logs and metrics. Two dashboards are available: first is the default Kong dashboard which displays Kong metrics, while the second is a custom dashboard, which displays multiple windows for displaying log messages gathered from the auth and core services. The service is available on port 3000. 

## Running using Play With Docker

For running the application using [Play With Docker](https://labs.play-with-docker.com/) a Swarm with 1 manager and 2 workers will be set up.
On the manager node, we will load the config repository (from Gitlab) and enter the `docker login` command to connect to the Gitlab image registry.
```
docker login gitlab.cs.pub.ro:5050
```
On each of the three nodes the Loki logging plugin will be installed.
```
docker plugin install grafana/loki-docker-driver:latest --alias loki --grant-all-permissions
```
To set the logging driver to the Loki one, we will modify the Docker daemon. A potential configuration for the `/etc/docker/daemon.json` file can be found in the file `/pwd-init/daemon.json`:
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

Finally, we will restart the Docker service on each node:
```
kill -9 `pgrep dockerd`; dockerd > /docker.log 2>&1 &
```

## Testing

To test the endpoints exposed using Kong, the file `/tests/trading-platform.postman_collection.json`, which contains a collection of Postman tests can be used. Using environment variables the user can set the customer tokens, `TOKENn`, and the host address, `HOSTNAME`.

## Related repositories
- Auth service: https://github.com/stefanastase/stock-trading-platform-auth
- Business logic: https://github.com/stefanastase/stock-trading-platform-core
- Portfolio management: https://github.com/stefanastase/stock-trading-platform-portfolio-mgmt
- Order management: https://github.com/stefanastase/stock-trading-platform-order-mgmt
