using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class OutLineEdgeDetection : MonoBehaviour
{
    public Shader edgeDetectShader;
    private Material edgeDetectMaterial = null;
    public Material material {  
        get {
            if (edgeDetectShader == null) {
			    return null;
		    }
		
		    if (edgeDetectShader.isSupported && edgeDetectMaterial && edgeDetectMaterial.shader == edgeDetectShader)
		    	return edgeDetectMaterial;
		
		    if (!edgeDetectShader.isSupported) {
		    	return null;
		    }
		    else {
		    	edgeDetectMaterial = new Material(edgeDetectShader);
		    	edgeDetectMaterial.hideFlags = HideFlags.DontSave;
		    	if (edgeDetectMaterial)
		    		return edgeDetectMaterial;
		    	else 
		    		return null;
		    }
            return edgeDetectMaterial;
        }  
    }

    [Range(0.0f, 1.0f)]
    public float edgesOnly = 0.0f;

    public Color edgeColor = Color.black;

    public Color backgroundColor = Color.white;


    void OnRenderImage(RenderTexture src, RenderTexture dest) {
        if (material != null) {
            material.SetFloat("_EdgeOnly", edgesOnly);
            material.SetColor("_EdgeColor", edgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);

            Graphics.Blit(src, dest, material);
        } else {
            Graphics.Blit(src, dest);
        }
    }
}
