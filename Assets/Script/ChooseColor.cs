//参考: https://zhuanlan.zhihu.com/p/461032053

using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ChooseColor : MonoBehaviour
{

    private static readonly int Threshold = Shader.PropertyToID("_Threshold");
    private static readonly int IsVerse = Shader.PropertyToID("_IsVerse");
    private Material _Material = null;
    private Material _Material2 = null;
    public float speed = 0.05f;

    enum ChooseState
    {
        none,
        first,
        second,
    }

    private ChooseState _chooseState = ChooseState.none;

    void Start()
    {
        Material[] materials = GetComponent<Renderer>().materials;
        _Material = materials[0];
        _Material2 = materials[1];
        _Material.SetFloat(Threshold, 2);
        _Material2.SetFloat(Threshold, -2);
    }

    void Update()
    {
        
        if (Input.GetKeyDown(KeyCode.Alpha1))
        {
            _chooseState = ChooseState.first;
        }

        if (Input.GetKeyDown(KeyCode.Alpha2))
        {
            _chooseState = ChooseState.second;
        }

        if (_chooseState == ChooseState.first)
        {
            _Material.SetInt(IsVerse, 1);
            if (_Material.GetFloat(Threshold) < -2)
            {
                // _Material.SetFloat(Threshold, -2);
                return;
            }
            _Material.SetFloat(Threshold, _Material.GetFloat(Threshold) - speed);
        }
        else
        {
            _Material.SetInt(IsVerse, 0);
            if (_Material.GetFloat(Threshold) > 2)
            {
                // _Material.SetFloat(Threshold, 2);
                return;
            }
            _Material.SetFloat(Threshold, _Material.GetFloat(Threshold) + speed);
        }
        
        
        if (_chooseState == ChooseState.second)
        {
            _Material2.SetInt(IsVerse, 1);
            if (_Material2.GetFloat(Threshold) < -2)
            {
                // _Material2.SetFloat(Threshold, -2);
                return;
            }
            _Material2.SetFloat(Threshold, _Material2.GetFloat(Threshold) - speed);
        }
        else
        {
            _Material2.SetInt(IsVerse, 0);
            if (_Material2.GetFloat(Threshold) > 2)
            {
                // _Material2.SetFloat(Threshold, 2);
                return;
            }
            _Material2.SetFloat(Threshold, _Material2.GetFloat(Threshold) + speed);
        }
        
    }
}
