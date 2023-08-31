import time
from locust import HttpUser, task, between, constant_throughput
import json
import random

class JoeLocustTester(HttpUser):
    wait_time = constant_throughput(1)

    @task
    def v21_simple(self):
        pair = self.random_v21_pair()
        tx = pair['token_x']
        ty = pair['token_y']
        bs = pair['bin_step']
        self.client.get(f"/v2_1/prices/{tx}/{ty}/{bs}")

    def random_v21_pair(self):
        # Opening JSON file
        f = open('v21_pairs.json')

        data = json.load(f)

        return random.choice(data)
    
    @task
    def v2_simple(self):
        pair = self.random_v20_pair()
        tx = pair['token_x']
        ty = pair['token_y']
        bs = pair['bin_step']
        self.client.get(f"/v2/prices/{tx}/{ty}/{bs}")

    def random_v20_pair(self):
        # Opening JSON file
        f = open('v20_pairs.json')

        data = json.load(f)

        return random.choice(data)

    def random_v21_batch(self):
        pass