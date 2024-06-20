using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SetShaderOnQuad : MonoBehaviour
{
    private Material material;
    [SerializeField] private Shader shader;
    void Start()
    {
        material = new Material(shader);
        GetComponent<MeshRenderer>().material = material;
    }

    // Update is called once per frame
    void Update()
    {
         
    }
}
