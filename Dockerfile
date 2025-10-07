FROM python:3.10-slim

WORKDIR /app
COPY . /app

RUN pip install --no-cache-dir flask

EXPOSE 5000

CMD ["python", "-m", "flask", "--app", "app", "run", "--host=0.0.0.0"]

