FROM python:3.10.6-alpine

WORKDIR /srv

COPY requirment.txt .

RUN pip install -r requirment.txt

COPY . .

CMD [ "python3", "-m", "flask", "run", "--port=8888", "--host=0.0.0.0" ]