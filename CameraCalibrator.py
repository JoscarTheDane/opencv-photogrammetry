#!/usr/bin/env python3
import cv2
import numpy as np
import sys
import os

def calibrate_from_video(video_path,
                         checkerboard_dims=(9,6),
                         square_size=1.0):
    """
    Calibrate a camera from a video of a checkerboard.
    Writes results to <video_basename>_calib.txt in the same folder.
    """
    rows, cols = checkerboard_dims
    # prepare object points
    objp = np.zeros((rows*cols, 3), np.float32)
    objp[:,:2] = np.mgrid[0:rows,0:cols].T.reshape(-1,2)
    objp *= square_size

    objpoints = []
    imgpoints = []

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        print(f"ERROR: cannot open {video_path}")
        sys.exit(1)

    frame_idx = 0
    while True:
        ret, frame = cap.read()
        if not ret:
            break
        frame_idx += 1
        gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        ok, corners = cv2.findChessboardCorners(
            gray, (rows, cols),
            cv2.CALIB_CB_ADAPTIVE_THRESH | cv2.CALIB_CB_NORMALIZE_IMAGE
        )
        if ok:
            cv2.cornerSubPix(
                gray, corners, (11,11), (-1,-1),
                (cv2.TERM_CRITERIA_EPS+cv2.TERM_CRITERIA_MAX_ITER,30,0.001)
            )
            imgpoints.append(corners)
            objpoints.append(objp)

    cap.release()

    if len(objpoints) < 3:
        print("Not enough detections for calibration.")
        sys.exit(1)

    h, w = gray.shape
    ret, K, dist, rvecs, tvecs = cv2.calibrateCamera(
        objpoints, imgpoints, (w,h), None, None
    )
    if not ret:
        print("Calibration failed.")
        sys.exit(1)

    # prepare output file
    folder = os.path.dirname(video_path)
    base   = os.path.splitext(os.path.basename(video_path))[0]
    out_txt = os.path.join(folder, base + "_calib.txt")

    with open(out_txt, 'w') as f:
        f.write(f"Video: {video_path}\n\n")
        f.write("INTRINSIC CAMERA MATRIX (K):\n")
        f.write(np.array2string(K, precision=6, separator=', ') + "\n\n")
        f.write("DISTORTION COEFFICIENTS (k1,k2,p1,p2,[k3]):\n")
        f.write(np.array2string(dist.ravel(), precision=6, separator=', ') + "\n\n")
        f.write(f"Found extrinsics for {len(rvecs)} frames:\n")
        for i, (r, t) in enumerate(zip(rvecs, tvecs)):
            f.write(f"--- Frame {i:03d} ---\n")
            f.write("rvec: " + np.array2string(r.ravel(), precision=6, separator=', ') + "\n")
            f.write("tvec: " + np.array2string(t.ravel(), precision=6, separator=', ') + "\n\n")

    print("Calibration complete.")
    print("Wrote results to:", out_txt)
    return K, dist, rvecs, tvecs

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python calibrate_from_video.py <path_to_video>")
        sys.exit(1)
    video = sys.argv[1]
    calibrate_from_video(video,
                         checkerboard_dims=(9,6),
                         square_size=1.0)