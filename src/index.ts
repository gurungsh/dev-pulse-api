import express, { Request, Response } from "express";
import cors from "cors";
import { PrismaClient } from "@prisma/client";

const app = express();
const prisma = new PrismaClient();

app.use(cors());
app.use(express.json());

interface UpdateServiceBody {
  id?: number;
  name: string;
  status: string;
}

// GET /api/v1/services
app.get("/api/v1/services", async (req: Request, res: Response) => {
  const { id, name } = req.query;

  try {
    const whereClause: any = {};

    if (id) {
      whereClause.id = Number(id);
    }

    if (name) {
      whereClause.name = {
        contains: String(name),
        mode: "insensitive",
      };
    }

    const services = await prisma.service.findMany({
      where: whereClause,
      orderBy: { id: "asc" },
    });
    res.json(services);
  } catch (err: any) {
    res.status(500).json({ error: err.message });
  }
});

// POST /api/v1/services
app.post(
  "/api/v1/services",
  async (req: Request<{}, {}, UpdateServiceBody>, res: Response) => {
    const { id, name, status } = req.body;

    try {
      if (id) {
        const updated = await prisma.service.update({
          where: { id },
          data: { name, status },
        });
        return res.json(updated);
      }

      const created = await prisma.service.create({
        data: { name, status },
      });
      return res.json(created);
    } catch (err: any) {
      return res.status(500).json({ error: err.message });
    }
  },
);

const PORT = process.env.PORT;
app.listen(PORT, () =>{
    console.log(`Server listening on port ${PORT}`);
});