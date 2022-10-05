import express, { Request, Response } from 'express'
import { networkInterfaces } from 'os'

const app = express()
const port = 3000

app.get('/', (req: Request, res: Response) => {
    const nets = networkInterfaces();
    const results = Object.create(null);
    for (const name of Object.keys(nets)) {
        const network = nets[name];
        if (network !== undefined) {
            for (const net of network) {
                const familyV4Value = typeof net.family === 'string' ? 'IPv4' : 4
                if (net.family === familyV4Value && !net.internal) {
                    if (!results[name]) {
                        results[name] = [];
                    }
                    results[name].push(net.address);
                }
            }
        }        
    }

    res.send(`Hello World, aws load balancer, the ip address is ${JSON.stringify(results)}`)
})

app.get('/health', (req: Request, res: Response) => {
    res.send("health is good")
})

app.listen(port, () => {
    console.log(`App listening on the port ${port}`)    
})