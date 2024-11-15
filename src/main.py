import io
import os
import shutil
import tarfile

import numpy as np
import scipy as sp
import tensorflow as tf
import wfdb
from flask import Flask, jsonify, request

app = Flask(__name__)

DIAGNOSES_LIST = ["1AVB", "2AVB", "3AVB", "ABQRS", "AFIB", "AFLT", "ALMI", "AMI", "ANEUR", "ASMI", "BIGU", "CLBBB", "CRBBB", "DIG", "EL", "HVOLT", "ILBBB", "ILMI", "IMI", "INJAL", "INJAS", "INJIL", "INJIN", "INJLA", "INVT", "IPLMI", "IPMI", "IRBBB", "ISCAL", "ISCAN", "ISCAS", "ISCIL", "ISCIN", "ISCLA", "ISC_", "IVCD", "LAFB", "LAO/LAE", "LMI", "LNGQT", "LOWT", "LPFB", "LPR", "LVH", "LVOLT", "NDT", "NORM", "NST_", "NT_", "PAC", "PACE", "PMI", "PRC(S)", "PSVT", "PVC", "QWAVE", "RAO/RAE", "RVH", "SARRH", "SBRAD", "SEHYP", "SR", "STACH", "STD_", "STE_", "SVARR", "SVTAC", "TAB_", "TRIGU", "VCLVH", "WPW"]


@app.route("/", methods=["POST"])
def inference():
    try:
        binary_buffer = io.BytesIO(request.data)
        with tarfile.open(fileobj=binary_buffer, mode="r:gz") as tar:
            tar.extractall(path="/tmp")
        
        model = tf.keras.models.load_model("/tmp/data/model.keras")

        result = []
        for file in [f.replace(".dat", "") for f in os.listdir("/tmp/data") if f.endswith(".dat")]:
            ecg = wfdb.rdsamp(f"/tmp/data/{file}")
            ecg_resampled = sp.signal.resample(ecg[0], 1000, axis=0)
            y_hat = model.predict(np.expand_dims(ecg_resampled, 0))
            y_threshold = (y_hat > 0.5)
            y_diagnoses = ",".join([DIAGNOSES_LIST[i] for i in range(len(y_threshold[0])) if y_threshold[0][i]])
            result.append({"id": file, "prediction": y_diagnoses})
        
        return jsonify({
            "result": result,
        })
    except Exception as e:
        return jsonify({"error": str(e)}), 500
    finally:
        shutil.rmtree("/tmp/data")


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=5000, debug=True)