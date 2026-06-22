void cambiarEstado(int estado){

  switch(estado){

  case 0:

    volumenObjetivo[0] = 1.0;
    volumenObjetivo[1] = 0.0;
    volumenObjetivo[2] = 0.0;
    volumenObjetivo[3] = 0.0;

    break;

  case 1:

    volumenObjetivo[0] = 1.0;
    volumenObjetivo[1] = 1.0;
    volumenObjetivo[2] = 0.0;
    volumenObjetivo[3] = 0.0;

    break;

  case 2:

    volumenObjetivo[0] = 1.0;
    volumenObjetivo[1] = 1.0;
    volumenObjetivo[2] = 1.0;
    volumenObjetivo[3] = 0.0;

    break;

  case 3:

    volumenObjetivo[0] = 1.0;
    volumenObjetivo[1] = 1.0;
    volumenObjetivo[2] = 1.0;
    volumenObjetivo[3] = 1.0;

    break;
  }
}
