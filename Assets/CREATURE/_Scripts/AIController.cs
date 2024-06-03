using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.AI;

public class AIController : MonoBehaviour
{
    private  GameObject destination;
    //private  GameObject player;
    private NavMeshAgent agent;

    public float DistanceRelease;

    
    void Start()
    {
        destination = GameObject.FindGameObjectWithTag("Destination");
        //player = GameObject.FindGameObjectWithTag("Player");

        agent = GetComponent<NavMeshAgent>();

        //agent.SetDestination(destination.transform.position);

    }

    void Update()
    {
        

            
        
        float dist = Vector3.Distance(this.transform.position, destination.transform.position);
        //print("Distance: " + dist);
        
        if(dist< DistanceRelease){
            agent.SetDestination(destination.transform.position);           
        }
        

    }

    
    
}
