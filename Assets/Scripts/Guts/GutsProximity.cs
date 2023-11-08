using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Splines;
using Unity.Mathematics;
using System;

public class GutsProximity : MonoBehaviour
{
    [Header("Renderers")]
    public SplineContainer _splineContainer;
    public SplineExtrude _splineGeometry;
    public MeshRenderer _splineRenderer;
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
            followerTransform.position = worldSpaceNearestPoint;
            _splineContainer.Spline.Clear();
            _splineRenderer.enabled = true;
            _splineContainer.Spline.Add(new BezierKnot(_splineContainer.transform.InverseTransformPoint(followerTransform.position)));
            
            var newTangent = CadaverGutsManager.Vector3ToFloat3(((playerTransform.position - followerTransform.position).normalized -   Vector3.up).normalized);
            var newTangent2 = CadaverGutsManager.Vector3ToFloat3(((playerTransform.position - followerTransform.position).normalized +   Vector3.up).normalized);
            _splineContainer.Spline.Add(new BezierKnot(_splineContainer.transform.InverseTransformPoint(playerTransform.position), newTangent, newTangent2));
            _splineContainer.Spline.SetTangentModeNoNotify(0, TangentMode.AutoSmooth);
            _splineContainer.Spline.SetTangentModeNoNotify(1, TangentMode.Mirrored);
            _splineGeometry.Rebuild();
            
#if UNITY_EDITOR
            Debug.DrawRay(playerTransform.position, worldSpaceNearestPoint - playerTransform.position, Color.green);
            //Debug.Log("nearestPoint: " + nearestPoint + " " + (worldSpaceNearestPoint - playerTransform.position).magnitude + " " + nearestInterpolation);
#endif
        }
        else
        {
            _splineRenderer.enabled = false;
#if UNITY_EDITOR
            Debug.DrawRay(playerTransform.position, worldSpaceNearestPoint - playerTransform.position, Color.red);
#endif
        }
    }
}
