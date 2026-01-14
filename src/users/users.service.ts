import { Injectable, ConflictException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Users } from './entity/users.entity';
import { RegisterUserDto } from './dto/register.dto';
import * as bcrypt from 'bcryptjs';

@Injectable()
export class UsersService {
  constructor(
    @InjectRepository(Users)
    private readonly usersRepository: Repository<Users>,
  ) {}

  // 注册新用户
  async registerUser(registerUserDto: RegisterUserDto): Promise<string> {
    const registerEmail = await this.usersRepository.findOne({
      where: { email: registerUserDto.email },
    });

    if (registerEmail) {
      throw new ConflictException('邮箱已经被注册');
    }

    const saltRounds = 10;
    const hashedPassword = await bcrypt.hash(
      registerUserDto.password,
      saltRounds,
    );

    const newUser = this.usersRepository.create({
      email: registerUserDto.email,
      password: hashedPassword,
    });

    await this.usersRepository.save(newUser);
    return 'users registered';
  }
}
