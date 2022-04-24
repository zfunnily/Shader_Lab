using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Circle : PostEffectBase
{
   public float width = 0.03f;
  void OnRenderImage (RenderTexture source, RenderTexture destination)
    {
        //计算波纹移动的距离，根据enable到目前的时间*速度求解
        //设置一系列参数
        _Material.SetFloat("_Width", width);
        
		Graphics.Blit (source, destination, _Material);
	}
}
