import time
import requests
import json
from faker import Faker

host = "dbtgraf1nix0.se.automationdemos.com"
loki = f"http://{host}:3100/loki/api/v1/"

fake = Faker("en_US")


def gen_data(num_entries):
    data = []
    for _ in range(num_entries):
        my_dict = {
            "age": fake.random_int(min=0, max=100),
            "person": {
                "name": fake.name(),
                "ratio": float(fake.random_int(min=155, max=389)) / 100,
            },
        }
        data.append(my_dict)
    return data


def push_data(values):
    headers = {"Content-Type": "application/json", "X-Scope-OrgID": "tenant1"}
    request = {"streams": [{"stream": {"test": "faker1"}, "values": values}]}
    r = requests.post(loki + "push", json=request, headers=headers)
    print(r.text)


data = gen_data(10)
print(data)
values = list(map(lambda x: [str(time.time_ns()), json.dumps(x)], data))
print(values)
push_data(values)
