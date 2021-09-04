using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class ObjectTracker : MonoBehaviour
{

    public GameObject trackedObject;


    // Start is called before the first frame update
    void Start()
    {
        this.transform.GetComponentInChildren<TextAnimated>().SetTrackedObject(trackedObject);
    }

    // Update is called once per frame
    void Update()
    {
        
    }
}
