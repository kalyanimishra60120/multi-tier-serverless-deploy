from flask import Flask, jsonify, request

app = Flask(__name__)

@app.route('/')
def home():
    return jsonify({"message": "Backend API working successfully!"})

@app.route('/data', methods=['POST'])
def data():
    data = request.get_json()
    return jsonify({"received": data})

if __name__ == '__main__':
    app.run(debug=True)

