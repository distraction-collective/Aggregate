using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Splines;
using Unity.Mathematics;
using System;

public class GutsProximity : MonoBehaviour
{
    [Header("Renderers")]
    public LineRenderer lineRenderer;
    public ParticleSystem hookedParticle;
    [Header("Detection Parameters")]
    public Transform playerTransform;
    public Transform followerTransform;
    public float detectRange = 2f;
    public int detectResolution = 5;
    public int detectIterations = 2;
    public SplineContainer m_splineObject;
    [SerializeField] private bool isAttached;
    private Spline chosenSpline;
    private Vector3 worldSpaceNearestPoint;
    private float3 nearestPoint;
    private float nearestInterpolation;
    // Start is called before the first frame update
    void Start()
    {
        chosenSpline = m_splineObject.Spline;
        isAttached = false;
    }

    // Update is called once per frame
    void Update()
    {
        DetectionTest();
    }

    public bool GetAttached() { return isAttached; }


    private void LateUpdate()
    {
        PlaceOnPosition();
    }

    //Get nearest point on spline to playerTransform, check if within distance
    private void DetectionTest()
    {
        SplineUtility.GetNearestPoint<Spline>(chosenSpline, playerTransform.position, out nearestPoint, out nearestInterpolation);
        worldSpaceNearestPoint = (Vector3)nearestPoint;
       
        isAttached = Vector3.Distance(playerTransform.position, worldSpaceNearestPoint) <= detectRange ? true : false;
        

    }

    private void PlaceOnPosition()
    {
        if (isAttached)
        {
            lineRenderer.SetPosition(0, worldSpaceNearestPoint);
            lineRenderer.SetPosition(1, (worldSpaceNearestPoint + playerTransform.position)/2 - Vector3.up*0.2f); //Example for it to sag
            lineRenderer.SetPosition(2, playerTransform.position);
            lineRenderer.enabled = true;
            followerTransform.position = worldSpaceNearestPoint;
#if UNITY_EDITOR
            Debug.DrawRay(playerTransform.position, worldSpaceNearestPoint - playerTransform.position, Color.green);
            //Debug.Log("nearestPoint: " + nearestPoint + " " + (worldSpaceNearestPoint - playerTransform.position).magnitude + " " + nearestInterpolation);
#endif
        }
        else
        {
            lineRenderer.enabled = false;
#if UNITY_EDITOR
            Debug.DrawRay(playerTransform.position, worldSpaceNearestPoint - playerTransform.position, Color.red);
#endif
        }
    }
}
