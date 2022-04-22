﻿using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class BlackHole : MonoBehaviour{
    public Transform blackHole;

    private Material mat;// Use this for initialization
    void Start (){ 
        mat = GetComponent<MeshRenderer>().material;
    }// Update is called once per frame
    void Update () {
        Debug.Log("blackHole.position: ");
        Debug.Log(blackHole.position);
        Debug.Log(mat.name);
        mat.SetVector("_BlackHolePos",blackHole.position);
    }
}