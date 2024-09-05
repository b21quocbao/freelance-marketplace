from flask import Flask, render_template, request

app = Flask(__name__)

@app.route('/', methods=["get", "post"])
def index():
  return render_template('index.html')

@app.route('/active_offers.html', methods=["get", "post"])
def active_offers():
  return render_template('active_offers.html')

@app.route('/create_offer', methods=["get", "post"])
def create_offer():
  return render_template('create_offer.html')

if __name__ == '__main__':
  app.run()